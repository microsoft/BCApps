// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using System.Visualization;

codeunit 783 "Relationship Performance Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        CreateOpportunityQst: Label 'Do you want to create an opportunity for contact %1?', Comment = '%1 - Contact No.';
        CreateOpportunityCaptionTxt: Label 'Create opportunity...';

    local procedure CalcTopFiveOpportunities(var TempOpportunity: Record Opportunity temporary)
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        Opportunity: Record Opportunity;
        I: Integer;
    begin
        TempOpportunity.DeleteAll();
        Opportunity.SetAutoCalcFields("Estimated Value (LCY)");
        Opportunity.SetRange(Closed, false);
        Opportunity.SetCurrentKey("Estimated Value (LCY)");
        Opportunity.Ascending(false);
        OnCalcTopFiveOpportunitiesOnAfterOpportunitySetFilters(Opportunity);
        if Opportunity.FindSet() then
            repeat
                I += 1;
                TempOpportunity := Opportunity;
                OnCalcTopFiveOpportunitiesOnBeforeTempOpportunityInsert(TempOpportunity, Opportunity);
                TempOpportunity.Insert();
            until (Opportunity.Next() = 0) or (I = 5);
    end;

    procedure DrillDown(var BusinessChartBuffer: Record "Business Chart Buffer"; var TempOpportunity: Record Opportunity temporary)
    var
        Opportunity: Record Opportunity;
    begin
        if TempOpportunity.FindSet() then begin
            TempOpportunity.Next(BusinessChartBuffer."Drill-Down X Index");
            Opportunity.SetRange("No.", TempOpportunity."No.");
            PAGE.Run(PAGE::"Opportunity List", Opportunity);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateData(var BusinessChartBuffer: Record "Business Chart Buffer"; var TempOpportunity: Record Opportunity temporary)
    var
        I: Integer;
    begin
        BusinessChartBuffer.Initialize();
        BusinessChartBuffer.AddDecimalMeasure(TempOpportunity.FieldCaption("Estimated Value (LCY)"), 1, BusinessChartBuffer."Chart Type"::StackedColumn);
        BusinessChartBuffer.SetXAxis(TempOpportunity.TableCaption(), BusinessChartBuffer."Data Type"::String);
        CalcTopFiveOpportunities(TempOpportunity);
        TempOpportunity.SetAutoCalcFields("Estimated Value (LCY)");
        OnUpdateDataOnAfterTempOpportunitySetFilters(TempOpportunity);
        if TempOpportunity.FindSet() then
            repeat
                I += 1;
                AddBusinessChartBufferColumn(BusinessChartBuffer, TempOpportunity);
                BusinessChartBuffer.SetValueByIndex(0, I - 1, TempOpportunity."Estimated Value (LCY)");
            until TempOpportunity.Next() = 0;
    end;

    local procedure AddBusinessChartBufferColumn(var BusinessChartBuffer: Record "Business Chart Buffer"; var TempOpportunity: Record Opportunity temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddBusinessChartBufferColumn(BusinessChartBuffer, TempOpportunity, IsHandled);
        if IsHandled then
            exit;

        BusinessChartBuffer.AddColumn(TempOpportunity.Description);
    end;

    procedure SendCreateOpportunityNotification(SegmentLine: Record "Segment Line")
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        CreateOpportunityNotification: Notification;
    begin
        CreateOpportunityNotification.Id := CreateGuid();
        CreateOpportunityNotification.Message := StrSubstNo(CreateOpportunityQst, SegmentLine."Contact No.");
        InteractionLogEntry.SetRange("User ID", UserId);
        InteractionLogEntry.SetRange("Contact No.", SegmentLine."Contact No.");
        InteractionLogEntry.FindFirst();
        CreateOpportunityNotification.SetData(
          GetSegmentLineNotificationDataItemID(), RecordsToXml(SegmentLine, InteractionLogEntry));
        CreateOpportunityNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        CreateOpportunityNotification.AddAction(
          CreateOpportunityCaptionTxt, CODEUNIT::"Relationship Performance Mgt.", 'CreateOpportunityFromSegmentLineNotification');
        CreateOpportunityNotification.Send();
    end;

    [Scope('OnPrem')]
    procedure CreateOpportunityFromSegmentLineNotification(var CreateOpportunityNotification: Notification)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        TempSegmentLine.Init();
        TempSegmentLine.Insert();
        XmlToRecords(
          CreateOpportunityNotification.GetData(GetSegmentLineNotificationDataItemID()), TempSegmentLine, InteractionLogEntry);
        InteractionLogEntry."Opportunity No." := TempSegmentLine.CreateOpportunity();
        InteractionLogEntry.Modify();
    end;

    local procedure RecordsToXml(SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry"): Text
    var
        RecRef: RecordRef;
        RootXmlElement: XmlElement;
        TableXmlElement: XmlElement;
        UnformattedXmlWriteOptions: XmlWriteOptions;
        NotificationXml: Text;
    begin
        RootXmlElement := XmlElement.Create('Notification');

        RecRef.GetTable(SegmentLine);
        TableXmlElement := XmlElement.Create(GetXmlTableName(RecRef));
        RootXmlElement.Add(TableXmlElement);
        AddFieldToXml(TableXmlElement, RecRef.Field(SegmentLine.FieldNo("Segment No.")));
        AddFieldToXml(TableXmlElement, RecRef.Field(SegmentLine.FieldNo(Description)));
        AddFieldToXml(TableXmlElement, RecRef.Field(SegmentLine.FieldNo("Campaign No.")));
        AddFieldToXml(TableXmlElement, RecRef.Field(SegmentLine.FieldNo("Salesperson Code")));
        AddFieldToXml(TableXmlElement, RecRef.Field(SegmentLine.FieldNo("Contact No.")));
        AddFieldToXml(TableXmlElement, RecRef.Field(SegmentLine.FieldNo("Contact Company No.")));
        RecRef.Close();

        RecRef.GetTable(InteractionLogEntry);
        TableXmlElement := XmlElement.Create(GetXmlTableName(RecRef));
        RootXmlElement.Add(TableXmlElement);
        AddFieldToXml(TableXmlElement, RecRef.Field(InteractionLogEntry.FieldNo("Entry No.")));
        RecRef.Close();

        UnformattedXmlWriteOptions.PreserveWhitespace := true;
        RootXmlElement.WriteTo(UnformattedXmlWriteOptions, NotificationXml);
        exit(NotificationXml);
    end;

    local procedure XmlToRecords(InText: Text; var SegmentLine: Record "Segment Line"; var InteractionLogEntry: Record "Interaction Log Entry")
    var
        RecRef: RecordRef;
        NotificationXmlDocument: XmlDocument;
        RootXmlElement: XmlElement;
    begin
        XmlDocument.ReadFrom(InText, NotificationXmlDocument);
        NotificationXmlDocument.GetRoot(RootXmlElement);

        RecRef.GetTable(SegmentLine);
        SetFieldFromXml(RecRef, SegmentLine.FieldNo("Segment No."), RootXmlElement);
        SetFieldFromXml(RecRef, SegmentLine.FieldNo(Description), RootXmlElement);
        SetFieldFromXml(RecRef, SegmentLine.FieldNo("Campaign No."), RootXmlElement);
        SetFieldFromXml(RecRef, SegmentLine.FieldNo("Salesperson Code"), RootXmlElement);
        SetFieldFromXml(RecRef, SegmentLine.FieldNo("Contact No."), RootXmlElement);
        SetFieldFromXml(RecRef, SegmentLine.FieldNo("Contact Company No."), RootXmlElement);
        RecRef.Modify();
        RecRef.SetTable(SegmentLine);
        RecRef.Close();

        RecRef.Open(DATABASE::"Interaction Log Entry");
        SetFieldFromXml(RecRef, InteractionLogEntry.FieldNo("Entry No."), RootXmlElement);
        RecRef.Find();
        RecRef.SetTable(InteractionLogEntry);
    end;

    local procedure AddFieldToXml(var TableXmlElement: XmlElement; FieldRef: FieldRef)
    var
        FieldXmlElement: XmlElement;
        FieldValue: Text;
    begin
        FieldXmlElement := XmlElement.Create(GetXmlNodeName(FieldRef.Number));
        FieldValue := Format(FieldRef.Value);
        if FieldValue <> '' then
            FieldXmlElement.Add(XmlText.Create(FieldValue));
        TableXmlElement.Add(FieldXmlElement);
    end;

    local procedure SetFieldFromXml(RecRef: RecordRef; FieldNo: Integer; RootXmlElement: XmlElement)
    var
        FieldRef: FieldRef;
        FieldXmlNode: XmlNode;
        FieldValue: Text;
    begin
        FieldRef := RecRef.Field(FieldNo);
        if RootXmlElement.SelectSingleNode(GetXmlTableName(RecRef) + '/' + GetXmlNodeName(FieldNo), FieldXmlNode) then
            FieldValue := FieldXmlNode.AsXmlElement().InnerText();
        FieldRef.Value := FieldValue;
    end;

    local procedure GetXmlNodeName(FieldNo: Integer): Text
    begin
        exit(StrSubstNo('F_%1', Format(FieldNo)));
    end;

    local procedure GetXmlTableName(RecRef: RecordRef): Text
    begin
        exit(DelChr(RecRef.Name, '=', ' '));
    end;

    local procedure GetSegmentLineNotificationDataItemID(): Text
    begin
        exit('SegmentLineNotificationTok');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddBusinessChartBufferColumn(var BusinessChartBuffer: Record "Business Chart Buffer"; var TempOpportunity: Record Opportunity temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTopFiveOpportunitiesOnAfterOpportunitySetFilters(var Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTopFiveOpportunitiesOnBeforeTempOpportunityInsert(var TempOpportunity: Record Opportunity temporary; Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDataOnAfterTempOpportunitySetFilters(var TempOpportunity: Record Opportunity temporary)
    begin
    end;
}

