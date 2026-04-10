namespace System.Device;

using System;
using System.Environment;

codeunit 9655 "Init. Server Printer Table"
{
    TableNo = Printer;

    trigger OnRun()
    begin
        InitTempPrinter(Rec);
    end;

    var
        PrinterNotFoundErr: Label 'The printer %1 was not found on the server.', Comment = '%1=a printer name';

    local procedure InitTempPrinter(var Printer: Record Printer)
    var
        PrinterSettings: DotNet PrinterSettings;
        PrinterSettingsCollection: DotNet PrinterSettings_StringCollection;
        PrinterName: Text;
        i: Integer;
    begin
        PrinterSettings := PrinterSettings.PrinterSettings();
        PrinterSettingsCollection := PrinterSettings.InstalledPrinters;
        for i := 0 to PrinterSettingsCollection.Count - 1 do begin
            PrinterName := PrinterSettingsCollection.Item(i);
            PrinterSettings.PrinterName := PrinterName;
            Printer.ID := CopyStr(PrinterName, 1, MaxStrLen(Printer.ID));
            if PrinterSettings.MaximumCopies > 1 then
                Printer.Insert();
        end;
    end;

    procedure ValidatePrinterName(var PrinterName: Text[250])
    begin
        if PrinterName = '' then
            exit;
        if not FindPrinterName(PrinterName, true) then
            Error(PrinterNotFoundErr, PrinterName);
    end;

    local procedure FindPrinterName(var PrinterName: Text[250]; AllowPartialMatch: Boolean): Boolean
    var
        TempPrinter: Record Printer temporary;
    begin
        InitTempPrinter(TempPrinter);

        if PrinterName <> '' then // If no name specified, then find the first.
            TempPrinter.SetRange(ID, PrinterName);
        if TempPrinter.FindFirst() then begin
            PrinterName := TempPrinter.ID;
            exit(true);
        end;
        if not AllowPartialMatch then
            exit(false);

        TempPrinter.SetFilter(ID, '%1', StrSubstNo('@*%1*', PrinterName));
        if TempPrinter.FindFirst() then begin
            PrinterName := TempPrinter.ID;
            exit(true);
        end;
        exit(false);
    end;

    procedure FindClosestMatchToClientDefaultPrinter(ReportID: Integer): Text[250]
    var
        PrinterName: Text[250];
    begin
        PrinterName := GetPrinterSelection(ReportID);
        if PrinterName = '' then
            PrinterName := GetLocalDefaultPrinter();
        if not FindPrinterName(PrinterName, false) then begin
            PrinterName := '';
            if FindPrinterName(PrinterName, true) then;
        end;
        exit(PrinterName);
    end;

    local procedure GetLocalDefaultPrinter(): Text[250]
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        [RunOnClient]
        PrinterSettings: DotNet PrinterSettings;
        PrinterName: Text;
        i: Integer;
    begin
        if ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Windows then
            exit('');
        PrinterSettings := PrinterSettings.PrinterSettings();
        PrinterName := DelChr(PrinterSettings.PrinterName, '<', '\');
        i := StrPos(PrinterName, '\');
        if i > 1 then
            PrinterName := CopyStr(PrinterName, i + 1);
        exit(PrinterName);
    end;

    local procedure GetPrinterSelection(ReportID: Integer): Text[250]
    var
        PrinterSelection: Record "Printer Selection";
    begin
        if ReportID = 0 then
            exit('');
        PrinterSelection.SetRange("User ID", UserId);
        PrinterSelection.SetRange("Report ID", ReportID);
        if not PrinterSelection.FindFirst() then begin
            PrinterSelection.SetRange("Report ID", 0);
            if PrinterSelection.FindFirst() then
                exit(PrinterSelection."Printer Name");
            PrinterSelection.SetRange("Report ID", ReportID);
            PrinterSelection.SetRange("User ID");
            if PrinterSelection.FindFirst() then;
        end;
        exit(PrinterSelection."Printer Name");
    end;
}

