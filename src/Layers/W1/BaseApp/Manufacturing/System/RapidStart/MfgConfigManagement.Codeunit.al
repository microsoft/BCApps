namespace System.IO;

using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;

codeunit 99000825 "Mfg. Config Management"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Management", 'OnFindPage', '', false, false)]
    local procedure OnFindPage(TableID: Integer; var PageID: Integer)
    begin
        case TableID of
            Database::"Manufacturing Setup":
                PageID := Page::"Manufacturing Setup";
            Database::Family:
                PageID := Page::Family;
            Database::"Production BOM Header":
                PageID := Page::"Production BOM";
            Database::"Work Shift":
                PageID := Page::"Work Shifts";
            Database::"Shop Calendar":
                PageID := Page::"Shop Calendars";
            Database::"Work Center Group":
                PageID := Page::"Work Center Groups";
            Database::"Standard Task":
                PageID := Page::"Standard Tasks";
            Database::"Routing Link":
                PageID := Page::"Routing Links";
            Database::Stop:
                PageID := Page::"Stop Codes";
            Database::Scrap:
                PageID := Page::"Scrap Codes";
            Database::"Machine Center":
                PageID := Page::"Machine Center List";
            Database::"Work Center":
                PageID := Page::"Work Center List";
            Database::"Routing Header":
                PageID := Page::Routing;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Management", 'OnAfterIsDefaultDimTable', '', false, false)]
    local procedure OnAfterIsDefaultDimTable(TableID: Integer; var Result: Boolean)
    begin
        case TableID of
            Database::Microsoft.Manufacturing.WorkCenter."Work Center":
                Result := true;
        end;
    end;
}