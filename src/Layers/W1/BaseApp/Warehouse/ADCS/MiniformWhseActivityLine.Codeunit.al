// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using Microsoft.Warehouse.Activity;
using System;
using System.Xml;

codeunit 7711 "Miniform Whse. Activity Line"
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

        if Rec.Code <> CurrentCode then
            PrepareData()
        else
            ProcessInput();

        Clear(DOMxmlin);
    end;

    var
        MiniformHeader: Record "Miniform Header";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ADCSCommunication: Codeunit "ADCS Communication";
        ADCSMgt: Codeunit "ADCS Management";
        RecRef: RecordRef;
        DOMxmlin: DotNet XmlDocument;
        ReturnedNode: DotNet XmlNode;
        RootNode: DotNet XmlNode;
        ADCSUserId: Text[250];
        Remark: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
#pragma warning disable AA0074
        Text000: Label 'Function not Found.';
#pragma warning disable AA0470
        Text004: Label 'Invalid %1.';
#pragma warning restore AA0470
        Text006: Label 'No input Node found.';
        Text007: Label 'Record not found.';
        Text008: Label 'End of Document.';
        Text009: Label 'Qty. does not match.';
        Text011: Label 'Invalid Quantity.';
#pragma warning restore AA0074
        CurrentCode: Text[250];
        StackCode: Text[250];
        ActiveInputField: Integer;
#pragma warning disable AA0074
        Text012: Label 'No Lines available.';
#pragma warning restore AA0074

    local procedure ProcessInput()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        FuncGroup: Record "Miniform Function Group";
        RecId: RecordID;
        TextValue: Text[250];
        TableNo: Integer;
        FldNo: Integer;
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := ReturnedNode.InnerText
        else
            Error(Text006);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecId) then begin
            RecRef.SetTable(WhseActivityLine);
            WhseActivityLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
            WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type");
            WhseActivityLine.SetRange("No.", WhseActivityLine."No.");
            RecRef.GetTable(WhseActivityLine);
            ADCSCommunication.SetRecRef(RecRef);
        end else begin
            ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            exit;
        end;

        FuncGroup.KeyDef := ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue);
        ActiveInputField := 1;

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                ADCSCommunication.RunPreviousMiniform(DOMxmlin);
            FuncGroup.KeyDef::First:
                ADCSCommunication.FindRecRef(0, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::LnDn:
                if not ADCSCommunication.FindRecRef(1, MiniformHeader."No. of Records in List") then
                    Remark := Text008;
            FuncGroup.KeyDef::LnUp:
                ADCSCommunication.FindRecRef(2, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Last:
                ADCSCommunication.FindRecRef(3, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::PgDn:
                if not ADCSCommunication.FindRecRef(4, MiniformHeader."No. of Records in List") then
                    Remark := Text008;
            FuncGroup.KeyDef::PgUp:
                ADCSCommunication.FindRecRef(5, MiniformHeader."No. of Records in List");
            FuncGroup.KeyDef::Reset:
                Reset(WhseActivityLine);
            FuncGroup.KeyDef::Register:
                begin
                    Register(WhseActivityLine);
                    if Remark = '' then
                        ADCSCommunication.RunPreviousMiniform(DOMxmlin)
                    else
                        SendForm(ActiveInputField);
                end;
            FuncGroup.KeyDef::Input:
                begin
                    Evaluate(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    case FldNo of
                        WhseActivityLine.FieldNo("Bin Code"):
                            CheckBinNo(WhseActivityLine, UpperCase(TextValue));
                        WhseActivityLine.FieldNo("Item No."):
                            CheckItemNo(WhseActivityLine, UpperCase(TextValue));
                        WhseActivityLine.FieldNo("Qty. to Handle"):
                            CheckQty(WhseActivityLine, TextValue);
                        else begin
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SetTable(WhseActivityLine);
                        end;
                    end;

                    WhseActivityLine.Modify();
                    RecRef.GetTable(WhseActivityLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    if Remark = '' then
                        if ADCSCommunication.LastEntryField(CurrentCode, FldNo) then begin
                            RecRef.GetTable(WhseActivityLine);
                            if not ADCSCommunication.FindRecRef(1, ActiveInputField) then
                                Remark := Text008
                            else
                                ActiveInputField := 1;
                        end else
                            ActiveInputField += 1;
                end;
            else
                Error(Text000);
        end;

        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc, FuncGroup.KeyDef::Register]) then
            SendForm(ActiveInputField);
    end;

    local procedure CheckBinNo(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    begin
        if InputValue = WhseActLine."Bin Code" then
            exit;

        Remark := StrSubstNo(Text004, WhseActLine.FieldCaption("Bin Code"));
    end;

    local procedure CheckItemNo(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        ItemIdent: Record "Item Identifier";
    begin
        if InputValue = WhseActLine."Item No." then
            exit;

        if not ItemIdent.Get(InputValue) then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption("Item No."));

        if ItemIdent."Item No." <> WhseActLine."Item No." then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption("Item No."));

        if (ItemIdent."Variant Code" <> '') and (ItemIdent."Variant Code" <> WhseActLine."Variant Code") then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption("Variant Code"));

        if (ItemIdent."Unit of Measure Code" <> '') and (ItemIdent."Unit of Measure Code" <> WhseActLine."Unit of Measure Code") then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption("Unit of Measure Code"));
    end;

    local procedure CheckQty(var WhseActLine: Record "Warehouse Activity Line"; InputValue: Text[250])
    var
        QtyToHandle: Decimal;
    begin
        if InputValue = '' then begin
            Remark := Text011;
            exit;
        end;

        Evaluate(QtyToHandle, InputValue);
        if QtyToHandle = Abs(QtyToHandle) then begin
            CheckItemNo(WhseActLine, WhseActLine."Item No.");
            if QtyToHandle <= WhseActLine."Qty. Outstanding" then
                WhseActLine.Validate("Qty. to Handle", QtyToHandle)
            else
                Remark := Text011;
        end else
            Remark := Text011;
    end;

    local procedure Reset(var WhseActLine2: Record "Warehouse Activity Line")
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        if not WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.") then
            Error(Text007);

        Remark := '';
        WhseActLine.Validate("Qty. to Handle", 0);
        WhseActLine.Modify();

        RecRef.GetTable(WhseActLine);
        ADCSCommunication.SetRecRef(RecRef);
        ActiveInputField := 1;
    end;

    local procedure Register(WhseActLine2: Record "Warehouse Activity Line")
    var
        WhseActLine: Record "Warehouse Activity Line";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
    begin
        if not WhseActLine.Get(WhseActLine2."Activity Type", WhseActLine2."No.", WhseActLine2."Line No.") then
            Error(Text007);
        if not BalanceQtyToHandle(WhseActLine) then
            Remark := Text009
        else begin
            WhseActivityRegister.ShowHideDialog(true);
            WhseActivityRegister.Run(WhseActLine);
        end;
    end;

    local procedure BalanceQtyToHandle(var WhseActivLine2: Record "Warehouse Activity Line"): Boolean
    var
        WhseActLine: Record "Warehouse Activity Line";
        QtyToPick: Decimal;
        QtyToPutAway: Decimal;
    begin
        WhseActLine.Copy(WhseActivLine2);
        WhseActLine.SetCurrentKey(WhseActLine."Activity Type", WhseActLine."No.", WhseActLine."Item No.", WhseActLine."Variant Code", WhseActLine."Action Type");
        WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type");
        WhseActLine.SetRange("No.", WhseActLine."No.");
        WhseActLine.SetRange("Action Type");

        if WhseActLine.Find('-') then
            repeat
                WhseActLine.SetRange("Item No.", WhseActLine."Item No.");
                WhseActLine.SetRange("Variant Code", WhseActLine."Variant Code");
                WhseActLine.SetTrackingFilterFromWhseActivityLine(WhseActLine);

                if (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Take) or
                   (WhseActivLine2.GetFilter("Action Type") = '')
                then begin
                    WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Take);
                    if WhseActLine.Find('-') then
                        repeat
                            QtyToPick := QtyToPick + WhseActLine."Qty. to Handle (Base)";
                        until WhseActLine.Next() = 0;
                end;

                if (WhseActivLine2."Action Type" = WhseActivLine2."Action Type"::Place) or
                   (WhseActivLine2.GetFilter("Action Type") = '')
                then begin
                    WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Place);
                    if WhseActLine.Find('-') then
                        repeat
                            QtyToPutAway := QtyToPutAway + WhseActLine."Qty. to Handle (Base)";
                        until WhseActLine.Next() = 0;
                end;

                if QtyToPick <> QtyToPutAway then
                    exit(false);

                WhseActLine.SetRange("Action Type");
                WhseActLine.Find('+');
                WhseActLine.SetRange("Item No.");
                WhseActLine.SetRange("Variant Code");
                WhseActLine.ClearTrackingFilter();
                QtyToPick := 0;
                QtyToPutAway := 0;
            until WhseActLine.Next() = 0;
        exit(true);
    end;

    local procedure PrepareData()
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        RecId: RecordID;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecId) then begin
            RecRef.SetTable(WhseActivityHeader);
            WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
            WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
            if not WhseActivityLine.FindFirst() then begin
                ADCSMgt.SendError(Text012);
                exit;
            end;
            RecRef.GetTable(WhseActivityLine);
            ADCSCommunication.SetRecRef(RecRef);
            ActiveInputField := 1;
            SendForm(ActiveInputField);
        end else
            Error(Text007);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        // Prepare Miniform
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, Remark, ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

