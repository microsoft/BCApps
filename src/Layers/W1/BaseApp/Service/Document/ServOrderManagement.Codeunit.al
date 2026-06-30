// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using System.Utilities;

codeunit 5900 ServOrderManagement
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot create a %1, because the %2 field is not empty.';
        Text001: Label 'You must specify %1, %2 and %3 in %4 %5, before you create new %6.';
#pragma warning restore AA0470
        Text004: Label 'There are no Customer Templates.';
#pragma warning disable AA0470
        Text005: Label 'Posting cannot be completed successfully. The %1 field on the service invoice lines should contain 1 because %2 %3 was replaced.';
        Text006: Label 'The %1 %2 is already assigned to %3 %4.';
        Text007: Label '%1 %2 was created.';
        Text008: Label 'There is not enough space to insert %1.';
        Text009: Label 'Travel fee in the %1 table with %2 %3 cannot be found.';
        Text011: Label 'There is no %1 for %2 %3.';
        Text012: Label 'You can not post %1 %2.\\%3 %4 in %5 line %6 is preventing it.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NewCustomerQst: Label 'This customer already exists.\\Do you want create a new %1 instead of using the existing one?', Comment = '%1 - Table caption';

    procedure ServHeaderLookup(DocumentType: Integer; var DocumentNo: Code[20]): Boolean
    var
        ServHeader: Record "Service Header";
    begin
        if ServHeader.Get(DocumentType, DocumentNo) then begin
            ServHeader.SetRange("Document Type", DocumentType);
            if PAGE.RunModal(0, ServHeader) = ACTION::LookupOK then begin
                DocumentNo := ServHeader."No.";
                exit(true);
            end;
        end;
        exit(false);
    end;

    procedure UpdateResponseDateTime(var ServItemLine: Record "Service Item Line"; Deleting: Boolean)
    var
        ServItemLine2: Record "Service Item Line";
        ServHeader: Record "Service Header";
        NewResponseDate: Date;
        NewResponseTime: Time;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateResponseDateTime(ServItemLine, Deleting, IsHandled);
        if IsHandled then
            exit;

        if not ServHeader.Get(ServItemLine."Document Type", ServItemLine."Document No.") then
            exit;

        if not Deleting then begin
            NewResponseDate := ServItemLine."Response Date";
            NewResponseTime := ServItemLine."Response Time";
        end;

        IsHandled := false;
        OnUpdateResponseDateTimeOnBeforeNewResponseDate(ServItemLine, IsHandled);
        if not IsHandled then begin
            ServItemLine2.Reset();
            ServItemLine2.SetRange("Document Type", ServItemLine."Document Type");
            ServItemLine2.SetRange("Document No.", ServItemLine."Document No.");
            ServItemLine2.SetFilter("Line No.", '<>%1', ServItemLine."Line No.");
            if ServItemLine2.Find('-') then begin
                if Deleting then begin
                    NewResponseDate := ServItemLine2."Response Date";
                    NewResponseTime := ServItemLine2."Response Time";
                end;
                repeat
                    if ServItemLine2."Response Date" < NewResponseDate then begin
                        NewResponseDate := ServItemLine2."Response Date";
                        NewResponseTime := ServItemLine2."Response Time"
                    end else
                        if (ServItemLine2."Response Date" = NewResponseDate) and
                        (ServItemLine2."Response Time" < NewResponseTime)
                        then
                            NewResponseTime := ServItemLine2."Response Time";
                until ServItemLine2.Next() = 0;
            end;

            if (ServHeader."Response Date" <> NewResponseDate) or (ServHeader."Response Time" <> NewResponseTime) then begin
                ServHeader."Response Date" := NewResponseDate;
                ServHeader."Response Time" := NewResponseTime;
                ServHeader.Modify();
            end;
        end;
    end;

    procedure CreateNewCustomer(var ServHeader: Record "Service Header")
    var
        Cust: Record Customer;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ServHeader."Customer No." <> '' then
            Error(
              Text000,
              Cust.TableCaption(), ServHeader.FieldCaption("Customer No."));
        if (ServHeader.Name = '') or (ServHeader.Address = '') or (ServHeader.City = '') then
            Error(
              Text001,
              ServHeader.FieldCaption(Name), ServHeader.FieldCaption(Address), ServHeader.FieldCaption(City), ServHeader.TableCaption(), ServHeader."No.", Cust.TableCaption());

        Cust.Reset();
        Cust.SetCurrentKey(Name, Address, City);
        Cust.SetRange(Name, ServHeader.Name);
        Cust.SetRange(Address, ServHeader.Address);
        Cust.SetRange(City, ServHeader.City);
        if Cust.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(NewCustomerQst, Cust.TableCaption()), false)
            then begin
                ServHeader.Validate("Customer No.", Cust."No.");
                exit;
            end;
        if CreateCustFromTemplate(Cust, ServHeader) then
            ServHeader.Validate("Customer No.", Cust."No.");
    end;

    procedure ReplacementCreateServItem(FromServItem: Record "Service Item"; ServiceLine: Record "Service Line"; ServShptDocNo: Code[20]; ServShptLineNo: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        ServMgtSetup: Record "Service Mgt. Setup";
        NewServItem: Record "Service Item";
        ResSkill: Record "Resource Skill";
        ServLogMgt: Codeunit ServLogManagement;
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        NoSeries: Codeunit "No. Series";
        SerialNo: Code[50];
        IsHandled: Boolean;
    begin
        if ServiceLine.Quantity <> 1 then
            Error(Text005, ServiceLine.FieldCaption(Quantity), FromServItem.TableCaption(), FromServItem."No.");

        SerialNo := '';
        TempTrackingSpecification.Reset();
        TempTrackingSpecification.SetCurrentKey(
          "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
          "Source Prod. Order Line", "Source Ref. No.");
        TempTrackingSpecification.SetRange("Source Type", DATABASE::"Service Line");
        TempTrackingSpecification.SetRange("Source Subtype", ServiceLine."Document Type");
        TempTrackingSpecification.SetRange("Source ID", ServiceLine."Document No.");
        TempTrackingSpecification.SetRange("Source Ref. No.", ServiceLine."Line No.");
        if TempTrackingSpecification.Find('-') then
            SerialNo := TempTrackingSpecification."Serial No.";

        if SerialNo <> '' then begin
            NewServItem.Reset();
            NewServItem.SetCurrentKey("Item No.", "Serial No.");
            NewServItem.SetRange("Item No.", ServiceLine."No.");
            NewServItem.SetRange("Variant Code", ServiceLine."Variant Code");
            NewServItem.SetRange("Serial No.", SerialNo);
            IsHandled := false;
            OnReplacementCreateServItemAfterNewServItemFilterSet(IsHandled, NewServItem);
            if not IsHandled then
                if NewServItem.FindFirst() then
                    Error(
                      Text006,
                      NewServItem.TableCaption(), NewServItem."No.", NewServItem.FieldCaption("Serial No."), NewServItem."Serial No.");
        end;

        IsHandled := false;
        OnReplacementCreateServItemAfterSerialNoCheck(NewServItem, FromServItem, SerialNo, ServiceLine, ServShptDocNo, ServShptLineNo, IsHandled); ///NEW
        if not IsHandled then begin
            NewServItem.Reset();
            ServMgtSetup.Get();
            NewServItem := FromServItem;
            NewServItem."No." := '';
            NewServItem."No. Series" := ServMgtSetup."Service Item Nos.";
            NewServItem."No." := NoSeries.GetNextNo(NewServItem."No. Series");
            NewServItem."Serial No." := SerialNo;
            NewServItem."Variant Code" := ServiceLine."Variant Code";
            NewServItem."Shipment Type" := NewServItem."Shipment Type"::Service;
            NewServItem."Sales/Serv. Shpt. Document No." := ServShptDocNo;
            NewServItem."Sales/Serv. Shpt. Line No." := ServShptLineNo;
            case ServiceLine."Spare Part Action" of
                ServiceLine."Spare Part Action"::"Temporary":
                    NewServItem.Status := NewServItem.Status::"Temporarily Installed";
                ServiceLine."Spare Part Action"::Permanent:
                    NewServItem.Status := NewServItem.Status::Installed;
            end;

            NewServItem.Insert();
        end;
        ResSkillMgt.CloneObjectResourceSkills(ResSkill.Type::"Service Item".AsInteger(), FromServItem."No.", NewServItem."No.");

        Clear(ServLogMgt);
        IsHandled := false;
        OnReplacementCreateServItemOnBeforeServItemAutoCreated(FromServItem, NewServItem, ServiceLine, IsHandled);
        if not IsHandled then begin
            ServLogMgt.ServItemAutoCreated(NewServItem);

            Clear(ServLogMgt);
            ServLogMgt.ServItemReplaced(FromServItem, NewServItem);
            FromServItem.Status := FromServItem.Status::Defective;
            FromServItem.Modify();
        end;
        case ServiceLine."Copy Components From" of
            ServiceLine."Copy Components From"::"Item BOM":
                CopyComponentsFromBOM(NewServItem);
            ServiceLine."Copy Components From"::"Old Service Item":
                CopyComponentsFromSI(FromServItem, NewServItem, true);
            ServiceLine."Copy Components From"::"Old Serv.Item w/o Serial No.":
                CopyComponentsFromSI(FromServItem, NewServItem, false);
        end;

        IsHandled := false;
        OnAfterReplacementCreateServItem(NewServItem, FromServItem, IsHandled);
        if not IsHandled then
            Message(
                Text007,
                NewServItem.TableCaption(), NewServItem."No.");
    end;

    procedure InsertServCost(ServInvLine: Record "Service Line"; CostType: Integer; LinktoServItemLine: Boolean): Boolean
    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServInvLine2: Record "Service Line";
        ServCost: Record "Service Cost";
        NextLine: Integer;
    begin
        ServHeader.Get(ServInvLine."Document Type", ServInvLine."Document No.");

        ServInvLine2.Reset();
        ServInvLine2.SetRange("Document Type", ServInvLine."Document Type");
        ServInvLine2.SetRange("Document No.", ServInvLine."Document No.");
        ServInvLine2 := ServInvLine;

        NextLine := ServInvLine.GetNextLineNo(ServInvLine, false);
        if NextLine = 0 then
            Error(Text008, ServInvLine.TableCaption());

        case CostType of
            0: // Travel Fee
                begin
                    ServHeader.TestField("Service Zone Code");
                    ServCost.Reset();
                    ServCost.SetCurrentKey("Service Zone Code");
                    ServCost.SetRange("Service Zone Code", ServHeader."Service Zone Code");
                    ServCost.SetRange("Cost Type", ServCost."Cost Type"::Travel);
                    if not ServCost.FindFirst() then
                        Error(
                          Text009,
                          ServCost.TableCaption(), ServCost.FieldCaption("Service Zone Code"), ServHeader."Service Zone Code");

                    ServInvLine2.Init();
                    if LinktoServItemLine then begin
                        ServInvLine2."Service Item Line No." := ServInvLine."Service Item Line No.";
                        ServInvLine2."Service Item No." := ServInvLine."Service Item No.";
                        ServInvLine2."Service Item Serial No." := ServInvLine."Service Item Serial No.";
                    end;
                    ServInvLine2."Document Type" := ServHeader."Document Type";
                    ServInvLine2."Document No." := ServHeader."No.";
                    ServInvLine2."Line No." := NextLine;
                    ServInvLine2.Type := ServInvLine2.Type::Cost;
                    ServInvLine2.Validate("No.", ServCost.Code);
                    ServInvLine2.Validate("Unit of Measure Code", ServCost."Unit of Measure Code");
                    ServInvLine2.Insert(true);
                    exit(true);
                end;
            1: // Starting Fee
                begin
                    ServMgtSetup.Get();
                    ServMgtSetup.TestField("Service Order Starting Fee");
                    ServCost.Get(ServMgtSetup."Service Order Starting Fee");
                    OnInsertServCostOnCostTypeOneOnAfterServCostGet(ServHeader, ServCost);
                    ServInvLine2.Init();
                    if LinktoServItemLine then begin
                        ServInvLine2."Service Item Line No." := ServInvLine."Service Item Line No.";
                        ServInvLine2."Service Item No." := ServInvLine."Service Item No.";
                        ServInvLine2."Service Item Serial No." := ServInvLine."Service Item Serial No.";
                    end;
                    ServInvLine2."Document Type" := ServHeader."Document Type";
                    ServInvLine2."Document No." := ServHeader."No.";
                    ServInvLine2."Line No." := NextLine;
                    ServInvLine2.Type := ServInvLine2.Type::Cost;
                    ServInvLine2.Validate("No.", ServCost.Code);
                    ServInvLine2.Validate("Unit of Measure Code", ServCost."Unit of Measure Code");
                    ServInvLine2.Insert(true);
                    exit(true);
                end;
            else
                exit(false);
        end;
    end;

    procedure FindContactInformation(CustNo: Code[20]): Code[20]
    var
        ServMgtSetup: Record "Service Mgt. Setup";
        Cust: Record Customer;
        ContBusRel: Record "Contact Business Relation";
        ContJobResp: Record "Contact Job Responsibility";
        Cont: Record Contact;
        ContactFound: Boolean;
    begin
        if Cust.Get(CustNo) then begin
            ServMgtSetup.Get();
            ContactFound := false;
            ContBusRel.Reset();
            ContBusRel.SetCurrentKey("Link to Table", "No.");
            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
            ContBusRel.SetRange("No.", Cust."No.");
            Cont.Reset();
            Cont.SetCurrentKey("Company No.");
            Cont.SetRange(Type, Cont.Type::Person);
            if ContBusRel.FindFirst() then begin
                Cont.SetRange("Company No.", ContBusRel."Contact No.");
                if Cont.Find('-') then
                    repeat
                        ContJobResp.Reset();
                        ContJobResp.SetRange("Contact No.", Cont."No.");
                        ContJobResp.SetRange("Job Responsibility Code", ServMgtSetup."Serv. Job Responsibility Code");
                        ContactFound := ContJobResp.FindFirst();
                    until (Cont.Next() = 0) or ContactFound;
            end;
            if ContactFound then begin
                Cont.Get(ContJobResp."Contact No.");
                exit(Cont."No.");
            end;
        end;
    end;

    procedure FindResLocationCode(ResourceNo: Code[20]; StartDate: Date): Code[10]
    var
        ResLocation: Record "Resource Location";
    begin
        ResLocation.Reset();
        ResLocation.SetCurrentKey("Resource No.", "Starting Date");
        ResLocation.SetRange("Resource No.", ResourceNo);
        ResLocation.SetRange("Starting Date", 0D, StartDate);
        if ResLocation.FindLast() then
            exit(ResLocation."Location Code");
    end;

    procedure CalcServTime(StartingDate: Date; StartingTime: Time; FinishingDate: Date; FinishingTime: Time; ContractNo: Code[20]; ContractCalendarExists: Boolean): Decimal
    var
        CalChange: Record "Customized Calendar Change";
        ServHour: Record "Service Hour";
        ServMgtSetup: Record "Service Mgt. Setup";
        CalendarMgmt: Codeunit "Calendar Management";
        TotTime: Decimal;
        TempDay: Integer;
        TempDate: Date;
        Holiday: Boolean;
        MiliSecPerDay: Decimal;
    begin
        MiliSecPerDay := 86400000;
        if (StartingDate = 0D) or (StartingTime = 0T) or (FinishingDate = 0D) or (FinishingTime = 0T) then
            exit(0);

        ServHour.Reset();
        if (ContractNo <> '') and ContractCalendarExists then begin
            ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::Contract);
            ServHour.SetRange("Service Contract No.", ContractNo)
        end else begin
            ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::" ");
            ServHour.SetRange("Service Contract No.", '');
        end;

        if ServHour.IsEmpty() then
            exit(
              Round(
                ((FinishingDate - StartingDate) * MiliSecPerDay +
                 CalendarMgmt.CalcTimeDelta(FinishingTime, StartingTime)) / 3600000, 0.01));

        TotTime := 0;
        TempDate := StartingDate;

        ServMgtSetup.Get();
        ServMgtSetup.TestField("Base Calendar Code");
        CalendarMgmt.SetSource(ServMgtSetup, CalChange);

        repeat
            TempDay := Date2DWY(TempDate, 1) - 1;
            ServHour.SetFilter("Starting Date", '<=%1', TempDate);
            ServHour.SetRange(Day, TempDay);
            if ServHour.FindLast() then begin
                Holiday := CalendarMgmt.IsNonworkingDay(TempDate, CalChange);
                if not Holiday or ServHour."Valid on Holidays" then begin
                    if StartingDate > FinishingDate then
                        exit(0);

                    if StartingDate = FinishingDate then
                        TotTime := CalendarMgmt.CalcTimeDelta(FinishingTime, GetStartingTime(StartingTime, ServHour."Starting Time"))
                    else
                        case TempDate of
                            StartingDate:
                                if ServHour."Ending Time" > StartingTime then
                                    TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", GetStartingTime(StartingTime, ServHour."Starting Time"));
                            FinishingDate:
                                if FinishingTime > ServHour."Starting Time" then
                                    TotTime := TotTime + CalendarMgmt.CalcTimeDelta(FinishingTime, ServHour."Starting Time");
                            else
                                TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time");
                        end;
                end;
            end;
            TempDate := TempDate + 1;
        until TempDate > FinishingDate;

        exit(Round(TotTime / 3600000, 0.01));
    end;

    procedure LookupServItemNo(var ServItemLine: Record "Service Item Line")
    var
        ServHeader: Record "Service Header";
        ServItem: Record "Service Item";
        ServContractLine: Record "Service Contract Line";
        ServItemList: Page "Service Item List";
        ServContractLineList: Page "Serv. Item List (Contract)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupServItemNo(ServItemLine, IsHandled);
        if IsHandled then
            exit;

        ServHeader.Get(ServItemLine."Document Type", ServItemLine."Document No.");

        if ServHeader."Contract No." = '' then begin
            if ServItem.Get(ServItemLine."Service Item No.") then
                ServItemList.SetRecord(ServItem);
            OnLookupServItemNoOnBeforeServItemReset(ServItemLine, ServItem, ServHeader);
            ServItem.Reset();
            ServItem.SetCurrentKey("Customer No.", "Ship-to Code");
            ServItem.SetRange("Customer No.", ServHeader."Customer No.");
            ServItem.SetRange("Ship-to Code", ServHeader."Ship-to Code");
            ServItem.SetFilter(Blocked, '<>%1', ServItem.Blocked::"All");
            OnLookupServItemNoOnAfterServItemSetFilters(ServItemLine, ServItem, ServHeader);
            ServItemList.SetTableView(ServItem);
            ServItemList.LookupMode(true);
            if ServItemList.RunModal() = ACTION::LookupOK then begin
                ServItemList.GetRecord(ServItem);
                ServItemLine.Validate("Service Item No.", ServItem."No.");
            end;
        end else begin
            if ServItemLine."Service Item No." <> '' then
                if ServContractLine.Get(
                     ServContractLine."Contract Type"::Contract,
                     ServItemLine."Contract No.", ServItemLine."Contract Line No.")
                then
                    ServContractLineList.SetRecord(ServContractLine);
            ServContractLine.Reset();
            ServContractLine.FilterGroup(2);
            ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
            ServContractLine.SetRange("Contract No.", ServHeader."Contract No.");
            ServContractLine.SetRange("Contract Status", ServContractLine."Contract Status"::Signed);
            ServContractLine.SetRange("Customer No.", ServHeader."Customer No.");
            ServContractLine.SetFilter("Starting Date", '<=%1', ServHeader."Order Date");
            ServContractLine.SetFilter("Contract Expiration Date", '>%1 | =%2', ServHeader."Order Date", 0D);
            ServContractLine.FilterGroup(0);
            ServContractLine.SetRange("Ship-to Code", ServHeader."Ship-to Code");
            ServContractLineList.SetTableView(ServContractLine);
            ServContractLineList.LookupMode(true);
            if ServContractLineList.RunModal() = ACTION::LookupOK then begin
                ServContractLineList.GetRecord(ServContractLine);
                ServItemLine.Validate("Service Item No.", ServContractLine."Service Item No.");
            end;
        end;
    end;

    procedure UpdatePriority(var ServItemLine: Record "Service Item Line"; Deleting: Boolean)
    var
        ServItemLine2: Record "Service Item Line";
        ServHeader: Record "Service Header";
        NewPriority: Enum "Service Priority";
    begin
        if not ServHeader.Get(ServItemLine."Document Type", ServItemLine."Document No.") then
            exit;

        if not Deleting then
            NewPriority := ServItemLine.Priority;

        ServItemLine2.Reset();
        ServItemLine2.SetRange("Document Type", ServItemLine."Document Type");
        ServItemLine2.SetRange("Document No.", ServItemLine."Document No.");
        ServItemLine2.SetFilter("Line No.", '<>%1', ServItemLine."Line No.");
        if ServItemLine2.Find('-') then
            repeat
                if ServItemLine2.Priority.AsInteger() > NewPriority.AsInteger() then
                    NewPriority := ServItemLine2.Priority;
            until ServItemLine2.Next() = 0;

        if ServHeader.Priority <> NewPriority then begin
            ServHeader.Priority := NewPriority;
            ServHeader.Modify();
        end;
    end;

    local procedure CopyComponentsFromSI(OldServItem: Record "Service Item"; NewServItem: Record "Service Item"; CopySerialNo: Boolean)
    var
        ServItemComponent: Record "Service Item Component";
        OldSIComponent: Record "Service Item Component";
    begin
        OldSIComponent.Reset();
        OldSIComponent.SetRange(Active, true);
        OldSIComponent.SetRange("Parent Service Item No.", OldServItem."No.");
        if OldSIComponent.Find('-') then
            repeat
                Clear(ServItemComponent);
                ServItemComponent.Init();
                ServItemComponent := OldSIComponent;
                ServItemComponent."Parent Service Item No." := NewServItem."No.";
                if not CopySerialNo then
                    ServItemComponent."Serial No." := '';
                ServItemComponent.Insert();
            until OldSIComponent.Next() = 0
        else
            Error(
              Text011,
              ServItemComponent.TableCaption(), OldServItem.FieldCaption("No."), OldServItem."No.");
    end;

    local procedure CopyComponentsFromBOM(var NewServItem: Record "Service Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyComponentsFromBOM(NewServItem, IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"ServComponent-Copy from BOM", NewServItem);
    end;

    procedure InServiceContract(var ServInvLine: Record "Service Line"): Boolean
    begin
        exit(ServInvLine."Contract No." <> '');
    end;

    local procedure GetStartingTime(StartingTime: Time; StartingServiceTime: Time): Time
    begin
        if StartingTime < StartingServiceTime then
            exit(StartingServiceTime);
        exit(StartingTime);
    end;

    procedure CheckServItemRepairStatus(ServHeader: Record "Service Header"; var ServItemLine: Record "Service Item Line" temporary; var ServLine: Record "Service Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        if ServItemLine.Get(ServHeader."Document Type", ServHeader."No.", ServLine."Service Item Line No.") then
            if ServItemLine."Repair Status Code" <> '' then begin
                RepairStatus.Get(ServItemLine."Repair Status Code");
                if not RepairStatus."Posting Allowed" then
                    Error(
                      Text012,
                      ServHeader.TableCaption(), ServHeader."No.", ServItemLine.FieldCaption("Repair Status Code"),
                      ServItemLine."Repair Status Code", ServItemLine.TableCaption(), ServItemLine."Line No.")
            end;
    end;

    procedure CopyCommentLines(FromDocumentType: Integer; ToDocumentType: Integer; FromNo: Code[20]; ToNo: Code[20])
    var
        ServCommentLine: Record "Service Comment Line";
        ServiceHeader: Record "Service Header";
        TableSubType: Enum "Service Document Type";
    begin
        case ToDocumentType of
            ServCommentLine."Table Name"::"Service Shipment Header".AsInteger():
                TableSubType := ServiceHeader."Document Type"::Order;
            ServCommentLine."Table Name"::"Service Cr.Memo Header".AsInteger():
                TableSubType := ServiceHeader."Document Type"::"Credit Memo"
        end;

        CopyCommentLinesWithSubType(FromDocumentType, ToDocumentType, FromNo, ToNo, TableSubType.AsInteger());
    end;

    procedure CopyCommentLinesWithSubType(FromDocumentType: Integer; ToDocumentType: Integer; FromNo: Code[20]; ToNo: Code[20]; FromTableSubType: Integer)
    var
        ServCommentLine: Record "Service Comment Line";
        ServCommentLine2: Record "Service Comment Line";
        IsHandled: Boolean;
    begin
        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", FromDocumentType);
        ServCommentLine.SetRange("Table Subtype", FromTableSubType);
        ServCommentLine.SetRange("No.", FromNo);
        if ServCommentLine.Find('-') then
            repeat
                ServCommentLine2 := ServCommentLine;
                ServCommentLine2."Table Name" := "Service Comment Table Name".FromInteger(ToDocumentType);
                ServCommentLine2."Table Subtype" := ServCommentLine2."Table Subtype"::"0";
                ServCommentLine2."No." := ToNo;
                IsHandled := false;
                OnCopyCommentLinesWithSubTypeOnBeforeServCommentLineInsert(ServCommentLine2, IsHandled);
                if not IsHandled then
                    ServCommentLine2.Insert();
            until ServCommentLine.Next() = 0;
    end;

    procedure CalcContractDates(var ServHeader: Record "Service Header"; var ServItemLine: Record "Service Item Line")
    var
        ServContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcContractDates(ServHeader, ServItemLine, IsHandled);
        if IsHandled then
            exit;

        if ServContractLine.Get(
             ServContractLine."Contract Type"::Contract,
             ServItemLine."Contract No.",
             ServItemLine."Contract Line No.")
        then begin
            ServContractLine.SuspendStatusCheck(true);
            if ServHeader."Finishing Date" <> 0D then
                ServContractLine."Last Service Date" := ServHeader."Finishing Date"
            else
                ServContractLine."Last Service Date" := ServHeader."Posting Date";
            ServContractLine."Last Planned Service Date" :=
              ServContractLine."Next Planned Service Date";
            ServContractLine.CalculateNextServiceVisit();
            ServContractLine."Last Preventive Maint. Date" := ServContractLine."Last Service Date";
        end;
        ServContractLine.Modify();
    end;

    procedure CalcServItemDates(var ServHeader: Record "Service Header"; ServItemNo: Code[20])
    var
        ServItem: Record "Service Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcServItemDates(ServHeader, ServItemNo, IsHandled);
        if IsHandled then
            exit;

        if ServItem.Get(ServItemNo) then begin
            if ServHeader."Finishing Date" <> 0D then
                ServItem."Last Service Date" := ServHeader."Finishing Date"
            else
                ServItem."Last Service Date" := ServHeader."Posting Date";
            ServItem.Modify();
        end;
    end;

    local procedure CopyCustFromServiceHeader(var Cust: Record Customer; ServiceHeader: Record "Service Header")
    begin
        Cust."No." := '';
        Cust.Validate(Name, ServiceHeader.Name);
        Cust."Name 2" := ServiceHeader."Name 2";
        Cust.Address := ServiceHeader.Address;
        Cust."Address 2" := ServiceHeader."Address 2";
        Cust.City := ServiceHeader.City;
        Cust."Post Code" := ServiceHeader."Post Code";
        Cust.Contact := ServiceHeader."Contact Name";
        Cust."Phone No." := ServiceHeader."Phone No.";
        Cust."E-Mail" := ServiceHeader."E-Mail";
        Cust.Blocked := Cust.Blocked::" ";

        OnAfterCopyCustFromServiceHeader(Cust, ServiceHeader);
    end;

    local procedure CreateCustDefaultDimFromTemplate(TableId: Integer; No: Code[20]; CustNo: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
    begin
        DefaultDim.Reset();
        DefaultDim.SetRange("Table ID", TableId);
        DefaultDim.SetRange("No.", No);
        if DefaultDim.FindSet() then
            repeat
                DefaultDim2 := DefaultDim;
                DefaultDim2."Table ID" := Database::Customer;
                DefaultDim2."No." := CustNo;
                DefaultDim2.Insert(true);
            until DefaultDim.Next() = 0;
    end;

    local procedure CreateCustInvoiceDiscFromTemplate(InvoiceDiscCode: Code[20]; CustNo: Code[20])
    var
        FromCustInvDisc: Record "Cust. Invoice Disc.";
        ToCustInvDisc: Record "Cust. Invoice Disc.";
    begin
        if InvoiceDiscCode <> '' then begin
            FromCustInvDisc.Reset();
            FromCustInvDisc.SetRange(Code, InvoiceDiscCode);
            if FromCustInvDisc.FindSet() then
                repeat
                    ToCustInvDisc.Init();
                    ToCustInvDisc.Code := CustNo;
                    ToCustInvDisc."Currency Code" := FromCustInvDisc."Currency Code";
                    ToCustInvDisc."Minimum Amount" := FromCustInvDisc."Minimum Amount";
                    ToCustInvDisc."Discount %" := FromCustInvDisc."Discount %";
                    ToCustInvDisc."Service Charge" := FromCustInvDisc."Service Charge";
                    OnBeforeToCustInvDiscInsert(ToCustInvDisc, FromCustInvDisc);
                    ToCustInvDisc.Insert();
                until FromCustInvDisc.Next() = 0;
        end;
    end;

    local procedure CreateCustFromTemplate(var Cust: Record Customer; ServHeader: Record "Service Header"): Boolean
    var
        CustTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        CustTempl.Reset();
        if not CustTempl.FindFirst() then
            Error(Text004);
        if CustomerTemplMgt.SelectCustomerTemplate(CustTempl) then begin
            CopyCustFromServiceHeader(Cust, ServHeader);
            Cust.CopyFromNewCustomerTemplate(CustTempl);
            CustomerTemplMgt.InitCustomerNo(Cust, CustTempl);
            Cust."Tax Area Code" := CustTempl."Tax Area Code";
            Cust."Tax Liable" := CustTempl."Tax Liable";
            Cust."Credit Limit (LCY)" := CustTempl."Credit Limit (LCY)";
            OnCreateCustFromTemplateOnBeforeCustInsert(Cust, CustTempl, ServHeader);
            Cust.Insert(true);

            if ServHeader."Contact Name" <> '' then begin
                CustContUpdate.InsertNewContactPerson(Cust, false);
                Cust.Modify();
            end;
            CreateCustDefaultDimFromTemplate(Database::"Customer Templ.", CustTempl.Code, Cust."No.");
            CreateCustInvoiceDiscFromTemplate(CustTempl."Invoice Disc. Code", Cust."No.");
            exit(true);
        end;

        exit(false);
    end;

    internal procedure IsCreditDocumentType(ServiceDocumentType: Enum "Service Document Type"): Boolean
    begin
        exit(ServiceDocumentType in [ServiceDocumentType::"Credit Memo"]);
    end;

    # region Service Item Blocked checks
    internal procedure CheckServiceItemBlockedForAll(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceItem: Record "Service Item";
    begin
        if ServiceItemLine."Service Item No." = '' then
            exit;

        if IsCreditDocumentType(ServiceItemLine."Document Type") then
            exit;

        ServiceItem.SetLoadFields(Blocked);
        ServiceItem.Get(ServiceItemLine."Service Item No.");
        ServiceItem.ErrorIfBlockedForAll();
    end;

    internal procedure CheckServiceItemBlockedForAll(var ServiceLine: Record "Service Line")
    var
        ServiceItem: Record "Service Item";
    begin
        if ServiceLine."Service Item No." = '' then
            exit;

        if IsCreditDocumentType(ServiceLine."Document Type") then
            exit;

        ServiceItem.SetLoadFields(Blocked);
        ServiceItem.Get(ServiceLine."Service Item No.");
        ServiceItem.ErrorIfBlockedForAll();
    end;
    # endregion Service Item Blocked checks

    # region Item Service Blocked checks
    internal procedure CheckItemServiceBlocked(var ServiceItemLine: Record "Service Item Line")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemServiceBlocked(ServiceItemLine, IsHandled);
        if IsHandled then
            exit;

        if ServiceItemLine."Item No." = '' then
            exit;

        Item.SetLoadFields(Blocked, "Service Blocked");
        Item.Get(ServiceItemLine."Item No.");
        Item.TestField(Blocked, false);
        if not IsCreditDocumentType(ServiceItemLine."Document Type") then
            Item.TestField("Service Blocked", false);

        if ServiceItemLine."Variant Code" <> '' then begin
            ItemVariant.SetLoadFields(Blocked, "Service Blocked");
            ItemVariant.Get(ServiceItemLine."Item No.", ServiceItemLine."Variant Code");
            ItemVariant.TestField(Blocked, false);
            if not IsCreditDocumentType(ServiceItemLine."Document Type") then
                ItemVariant.TestField("Service Blocked", false);
        end;
    end;

    internal procedure CheckItemServiceBlocked(var ServiceLine: Record "Service Line")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if ServiceLine.Type <> ServiceLine.Type::Item then
            exit;

        if ServiceLine."No." = '' then
            exit;

        Item.SetLoadFields(Blocked, "Service Blocked");
        Item.Get(ServiceLine."No.");
        Item.TestField(Blocked, false);
        if not IsCreditDocumentType(ServiceLine."Document Type") then
            Item.TestField("Service Blocked", false);

        if ServiceLine."Variant Code" <> '' then begin
            ItemVariant.SetLoadFields(Blocked, "Service Blocked");
            ItemVariant.Get(ServiceLine."No.", ServiceLine."Variant Code");
            ItemVariant.TestField(Blocked, false);
            if not IsCreditDocumentType(ServiceLine."Document Type") then
                ItemVariant.TestField("Service Blocked", false);
        end;
    end;
    # endregion Item Service Blocked checks

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcContractDates(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServItemDates(var ServiceHeader: Record "Service Header"; ServItemNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToCustInvDiscInsert(var ToCustInvoiceDisc: Record "Cust. Invoice Disc."; FromCustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateResponseDateTime(var ServItemLine: Record "Service Item Line"; var Deleting: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupServItemNoOnAfterServItemSetFilters(var ServItemLine: Record "Service Item Line"; var ServItem: Record "Service Item"; ServHeader: Record "Service Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupServItemNoOnBeforeServItemReset(var ServiceItemLine: Record "Service Item Line"; var ServiceItem: Record "Service Item"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplacementCreateServItemAfterNewServItemFilterSet(var IsHandled: Boolean; var NewServItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplacementCreateServItemAfterSerialNoCheck(var NewServItem: Record "Service Item"; FromServItem: Record "Service Item"; SerialNo: Code[50]; ServiceLine: Record "Service Line"; ServShptDocNo: Code[20]; ServShptLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplacementCreateServItemOnBeforeServItemAutoCreated(var FromServItem: Record "Service Item"; NewServItem: Record "Service Item"; ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReplacementCreateServItem(NewServItem: Record "Service Item"; FromServItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCustFromServiceHeader(var Cust: Record Customer; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServCostOnCostTypeOneOnAfterServCostGet(var ServHeader: Record "Service Header"; var ServCost: Record "Service Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateResponseDateTimeOnBeforeNewResponseDate(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupServItemNo(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyCommentLinesWithSubTypeOnBeforeServCommentLineInsert(var ServiceCommentLine2: Record "Service Comment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyComponentsFromBOM(var ServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustFromTemplateOnBeforeCustInsert(var Customer: Record Customer; CustomerTempl: Record "Customer Templ."; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemServiceBlocked(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;
}
