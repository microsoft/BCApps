// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using Microsoft.Warehouse.Journal;
using System;
using System.Xml;

codeunit 7713 "Miniform Phys.-Inventory"
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
        WhseJournalLine: Record "Warehouse Journal Line";
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
#pragma warning restore AA0074
        CurrentCode: Text[250];
        StackCode: Text[250];
        ActiveInputField: Integer;
#pragma warning disable AA0074
        Text012: Label 'No Lines available.';
#pragma warning restore AA0074

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
            Error(Text006);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));    // Key1 = TableNo
        RecRef.Open(TableNo);
        Evaluate(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));   // Key2 = RecordID
        if RecRef.Get(RecId) then begin
            RecRef.SetTable(WhseJournalLine);
            WhseJournalLine.SetRange("Journal Template Name", WhseJournalLine."Journal Template Name");
            WhseJournalLine.SetRange("Journal Batch Name", WhseJournalLine."Journal Batch Name");
            WhseJournalLine.SetRange("Location Code", WhseJournalLine."Location Code");
            RecRef.GetTable(WhseJournalLine);
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
            FuncGroup.KeyDef::Input:
                begin
                    Evaluate(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));

                    case FldNo of
                        WhseJournalLine.FieldNo("Bin Code"):
                            CheckBinNo(UpperCase(TextValue));
                        WhseJournalLine.FieldNo("Item No."):
                            CheckItemNo(UpperCase(TextValue));
                        else begin
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SetTable(WhseJournalLine);
                        end;
                    end;

                    WhseJournalLine.Modify();
                    RecRef.GetTable(WhseJournalLine);
                    ADCSCommunication.SetRecRef(RecRef);
                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    if Remark = '' then
                        if ADCSCommunication.LastEntryField(CurrentCode, FldNo) then begin
                            RecRef.GetTable(WhseJournalLine);
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

    local procedure CheckBinNo(InputValue: Text[250])
    begin
        if InputValue = WhseJournalLine."Bin Code" then
            exit;

        Remark := StrSubstNo(Text004, WhseJournalLine.FieldCaption("Bin Code"));
    end;

    local procedure CheckItemNo(InputValue: Text[250])
    var
        ItemIdent: Record "Item Identifier";
    begin
        if InputValue = WhseJournalLine."Item No." then
            exit;

        if not ItemIdent.Get(InputValue) then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption(Code));

        if ItemIdent."Item No." <> WhseJournalLine."Item No." then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption(Code));

        if (ItemIdent."Variant Code" <> '') and (ItemIdent."Variant Code" <> WhseJournalLine."Variant Code") then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption(Code));

        if ((ItemIdent."Unit of Measure Code" <> '') and (ItemIdent."Unit of Measure Code" <> WhseJournalLine."Unit of Measure Code"))
        then
            Remark := StrSubstNo(Text004, ItemIdent.FieldCaption(Code));
    end;

    local procedure PrepareData()
    var
        WhseJournalBatch: Record "Warehouse Journal Batch";
        RecId: RecordID;
        TableNo: Integer;
    begin
        XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode);

        Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo'));
        RecRef.Open(TableNo);
        Evaluate(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
        if RecRef.Get(RecId) then begin
            RecRef.SetTable(WhseJournalBatch);
            WhseJournalLine.SetRange("Journal Template Name", WhseJournalBatch."Journal Template Name");
            WhseJournalLine.SetRange("Journal Batch Name", WhseJournalBatch.Name);
            WhseJournalLine.SetRange("Location Code", WhseJournalBatch."Location Code");
            if not WhseJournalLine.FindFirst() then begin
                ADCSMgt.SendError(Text012);
                exit;
            end;
            RecRef.GetTable(WhseJournalLine);
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

